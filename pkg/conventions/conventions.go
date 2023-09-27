package conventions

import (
	"context"
	"encoding/json"
	"log"
	"os"

	corev1 "k8s.io/api/core/v1"

	"github.com/x95castle1/convention-server-framework/pkg/convention"
)

var Prefix = os.Getenv("ANNOTATION_PREFIX")
var ReadinessId = Prefix + "-readiness"
var ReadinessAnnotation = Prefix + "/readinessProbe"

var Conventions = []convention.Convention{
	&convention.BasicConvention{
		Id: ReadinessId,
		Applicable: func(ctx context.Context, target *corev1.PodTemplateSpec, metadata convention.ImageMetadata) bool {
			return getAnnotation(target, ReadinessAnnotation) != ""
		},
		Apply: func(ctx context.Context, target *corev1.PodTemplateSpec, containerIdx int, metadata convention.ImageMetadata, imageName string) error {
			readinessProbe := getAnnotation(target, ReadinessAnnotation)
			c := &target.Spec.Containers[containerIdx]

			if c.ReadinessProbe == nil {
				p, err := getProbe(readinessProbe)
				if err != nil {
					return err
				}
				log.Printf("Adding ReadinessProbe %+v", p)
				c.ReadinessProbe = p
			}
			return nil
		},
	},
}

func getProbe(config string) (*corev1.Probe, error) {
	probe := corev1.Probe{}
	err := json.Unmarshal([]byte(config), &probe)
	return &probe, err
}

func getAnnotation(pts *corev1.PodTemplateSpec, key string) string {
	if pts.Annotations == nil || len(pts.Annotations[key]) == 0 {
		return ""
	}
	return pts.Annotations[key]
}
